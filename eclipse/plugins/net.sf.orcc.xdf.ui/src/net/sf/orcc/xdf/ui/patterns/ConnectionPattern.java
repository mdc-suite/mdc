/*
 * Copyright (c) 2013, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.xdf.ui.patterns;

import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.xdf.ui.styles.StyleUtil;
import net.sf.orcc.xdf.ui.util.PropsUtil;

import org.eclipse.graphiti.features.context.IAddConnectionContext;
import org.eclipse.graphiti.features.context.IAddContext;
import org.eclipse.graphiti.features.context.ICreateConnectionContext;
import org.eclipse.graphiti.features.context.impl.AddConnectionContext;
import org.eclipse.graphiti.mm.GraphicsAlgorithmContainer;
import org.eclipse.graphiti.mm.algorithms.GraphicsAlgorithm;
import org.eclipse.graphiti.mm.algorithms.Polygon;
import org.eclipse.graphiti.mm.algorithms.Polyline;
import org.eclipse.graphiti.mm.pictograms.Anchor;
import org.eclipse.graphiti.mm.pictograms.AnchorContainer;
import org.eclipse.graphiti.mm.pictograms.ChopboxAnchor;
import org.eclipse.graphiti.mm.pictograms.Connection;
import org.eclipse.graphiti.mm.pictograms.ConnectionDecorator;
import org.eclipse.graphiti.mm.pictograms.FixPointAnchor;
import org.eclipse.graphiti.mm.pictograms.FreeFormConnection;
import org.eclipse.graphiti.mm.pictograms.PictogramElement;
import org.eclipse.graphiti.pattern.AbstractConnectionPattern;
import org.eclipse.graphiti.pattern.IFeatureProviderWithPatterns;
import org.eclipse.graphiti.pattern.IPattern;
import org.eclipse.graphiti.services.Graphiti;
import org.eclipse.graphiti.services.IGaService;
import org.eclipse.graphiti.services.IPeCreateService;

/**
 * Implements a visible connection between 2 ports.
 * 
 * Each connection links an input and an output port. A port can be represented
 * by an Input or an Output port directly contained in the network, or a port in
 * an Instance. In the second case, the real port is a port contained in an
 * Actor or in a Network, depending on how the instance has been refined.
 * 
 * @author Antoine Lorence
 * 
 */
public class ConnectionPattern extends AbstractConnectionPattern {

	private static enum PortKind {
		INPUT, OUTPUT
	}

	private static enum PortContainer {
		NETWORK, INSTANCE
	}

	private static enum ConnectionSide {
		SOURCE, TARGET
	}

	/**
	 * Define a simple utility class to encapsulate all information about a
	 * source or a target port. It is used to check validity of a connection,
	 * and to create the Connection instance to add in the Network.
	 * 
	 * @author Antoine Lorence
	 */
	public class PortInformation {
		private final Vertex vertex;
		private final Port port;
		private final PortKind kind;
		private final PortContainer container;

		public PortInformation(Vertex vertex, Port port, PortKind direction, PortContainer type) {
			this.vertex = vertex;
			this.port = port;
			this.kind = direction;
			this.container = type;
		}

		/**
		 * Return the vertex associated to the port. For an Instance port, it is
		 * the instance. For the current Network port, it is the port itself
		 * 
		 * @return
		 */
		public Vertex getVertex() {
			return vertex;
		}

		/**
		 * If the vertex is an instance, returns the Port of the refinement
		 * (actor or network) of this instance. In case of a port in the current
		 * Network, this method returns null.
		 * 
		 * @return
		 */
		public Port getPort() {
			return port;
		}

		/**
		 * Returns the port side (input or output)
		 * 
		 * @return
		 */
		public PortKind getKind() {
			return kind;
		}

		public PortContainer getContainer() {
			return container;
		}

		public ConnectionSide getConnectionSide() {
			if (container.equals(PortContainer.NETWORK)) {
				return kind == PortKind.INPUT ? ConnectionSide.SOURCE : ConnectionSide.TARGET;
			} else {
				return kind == PortKind.INPUT ? ConnectionSide.TARGET : ConnectionSide.SOURCE;
			}
		}
	}

	@Override
	public String getCreateName() {
		return "Connection";
	}

	@Override
	public String getCreateDescription() {
		return "Add a connection between 2 ports";
	}

	@Override
	public boolean canStartConnection(ICreateConnectionContext context) {
		final Anchor anchor = context.getSourceAnchor();
		final PortInformation src = getPortInformations(anchor);
		if (src == null) {
			return false;
		}

		if (src.getConnectionSide() == ConnectionSide.TARGET) {
			if (anchor.getIncomingConnections().size() > 0) {
				return false;
			}
		}
		return true;
	}

	@Override
	public boolean canCreate(ICreateConnectionContext context) {
		// The current diagram has a Network attached
		if (!(getBusinessObjectForPictogramElement(getDiagram()) instanceof Network)) {
			return false;
		}

		final PortInformation src = getPortInformations(context.getSourceAnchor());
		final PortInformation trgt = getPortInformations(context.getTargetAnchor());
		if (src == null || trgt == null) {
			return false;
		}

		// Disallow connection between 2 network ports
		if (src.getContainer() == PortContainer.NETWORK && trgt.getContainer() == PortContainer.NETWORK) {
			return false;
		}

		// Check incompatible connections source/target
		if (src.getConnectionSide() == trgt.getConnectionSide()) {
			return false;
		}

		// Check (for the target) if no connection is already targeting this
		// port
		if (src.getConnectionSide() == ConnectionSide.TARGET) {
			if (context.getSourceAnchor().getIncomingConnections().size() > 0) {
				return false;
			}
		} else if (trgt.getConnectionSide() == ConnectionSide.TARGET) {
			if (context.getTargetAnchor().getIncomingConnections().size() > 0) {
				return false;
			}
		} else {
			OrccLogger.warnln("Oops, unknown error appear in ConnectionPattern. A connection cannot be created "
							+ "between 2 sources or a bug may be fixed in the source code.");
			return false;
		}

		return true;
	}

	@Override
	public Connection create(ICreateConnectionContext context) {

		PortInformation src = getPortInformations(context.getSourceAnchor());
		final AddConnectionContext addContext;
		// Create connection context. In some case, connection source and target
		// need to be exchanged, to avoid arrow on the wrong side of the
		// connection shape
		if (src.getConnectionSide() != ConnectionSide.SOURCE) {
			addContext = new AddConnectionContext(context.getTargetAnchor(), context.getSourceAnchor());
			src = getPortInformations(context.getTargetAnchor());
		} else {
			addContext = new AddConnectionContext(context.getSourceAnchor(), context.getTargetAnchor());
		}

		final PortInformation tgt = getPortInformations(addContext.getTargetAnchor());
		// Create new business object
		final net.sf.orcc.df.Connection dfConnection = DfFactory.eINSTANCE.createConnection(src.getVertex(),
				src.getPort(), tgt.getVertex(), tgt.getPort());
		final Network network = (Network) getBusinessObjectForPictogramElement(getDiagram());
		network.add(dfConnection);

		addContext.setNewObject(dfConnection);
		final Connection newConnection = (Connection) getFeatureProvider().addIfPossible(addContext);

		return newConnection;
	}

	@Override
	public boolean canAdd(IAddContext context) {
		if (context instanceof IAddConnectionContext) {
			if (context.getNewObject() instanceof net.sf.orcc.df.Connection) {
				return true;
			}
		}
		return super.canAdd(context);
	}

	@Override
	public PictogramElement add(IAddContext context) {
		final IAddConnectionContext addConContext = (IAddConnectionContext) context;
		final net.sf.orcc.df.Connection addedConnection = (net.sf.orcc.df.Connection) context.getNewObject();
		final IPeCreateService peCreateService = Graphiti.getPeCreateService();
		final IGaService gaService = Graphiti.getGaService();

		// Create the connection
		final FreeFormConnection connection = peCreateService.createFreeFormConnection(getDiagram());
		connection.setStart(addConContext.getSourceAnchor());
		connection.setEnd(addConContext.getTargetAnchor());

		// Create the line corresponding to the connection
		final Polyline polyline = gaService.createPolyline(connection);
		final ConnectionDecorator cd = peCreateService.createConnectionDecorator(connection, false, 1.0, true);
		// Draw the arrow on the target side of the connection
		final GraphicsAlgorithm arrow = createArrow(cd);

		// Setup styles
		polyline.setStyle(StyleUtil.connection(getDiagram()));
		arrow.setStyle(StyleUtil.connection(getDiagram()));

		// create link and wire it
		link(connection, addedConnection);
		return connection;
	}

	/**
	 * Create the arrow to display on the target side of the connection
	 * 
	 * @param gaContainer
	 * @return
	 */
	private GraphicsAlgorithm createArrow(final GraphicsAlgorithmContainer gaContainer) {
		final int w = 12, l = 5;
		final int[] xy = new int[] { 0, 0, -w, l, -w, -l };
		final Polygon figure = Graphiti.getGaService().createPolygon(gaContainer, xy);
		figure.setLineVisible(false);

		return figure;
	}

	/**
	 * Retrieve all information related to a port in a diagram. Build
	 * corresponding PortInformation structure.
	 * 
	 * @param anchor
	 *            The anchor corresponding to a port in a Network or an Instance
	 * @return
	 */
	public PortInformation getPortInformations(final Anchor anchor) {
		if (anchor == null) {
			return null;
		}

		if (anchor instanceof FixPointAnchor) {
			// Instance port

			final FixPointAnchor brAnchor = (FixPointAnchor) anchor;
			final Port port = (Port) getBusinessObjectForPictogramElement(brAnchor);
			final PortKind kind = PropsUtil.isInstanceInPort(brAnchor) ? PortKind.INPUT : PortKind.OUTPUT;
			final Instance parentInstance = (Instance) getBusinessObjectForPictogramElement(brAnchor.getParent());

			return new PortInformation(parentInstance, port, kind, PortContainer.INSTANCE);

		} else if (anchor instanceof ChopboxAnchor) {
			// Network port

			final AnchorContainer container = anchor.getParent();
			final Port port = (Port) getBusinessObjectForPictogramElement(container);

			// Retrieve the pattern corresponding to the current port
			final IPattern ipattern = ((IFeatureProviderWithPatterns) getFeatureProvider())
					.getPatternForPictogramElement(anchor.getParent());

			// Check the type of this pattern to know the kind of the port
			final PortKind kind = ipattern instanceof InputNetworkPortPattern ? PortKind.INPUT
					: PortKind.OUTPUT;

			return new PortInformation(port, null, kind, PortContainer.NETWORK);
		}

		// Anchor without port ? Maybe an error here...
		return null;
	}
}
