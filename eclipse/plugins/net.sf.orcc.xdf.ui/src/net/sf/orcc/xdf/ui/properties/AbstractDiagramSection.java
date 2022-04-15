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
package net.sf.orcc.xdf.ui.properties;

import net.sf.orcc.df.Network;
import net.sf.orcc.ui.editor.PartialCalParser;
import net.sf.orcc.xdf.ui.diagram.XdfDiagramFeatureProvider;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.transaction.RecordingCommand;
import org.eclipse.emf.transaction.TransactionalEditingDomain;
import org.eclipse.graphiti.mm.pictograms.PictogramElement;
import org.eclipse.graphiti.pattern.IPattern;
import org.eclipse.graphiti.services.Graphiti;
import org.eclipse.graphiti.ui.platform.GFPropertySection;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.ui.IWorkbenchPart;
import org.eclipse.ui.forms.widgets.Form;
import org.eclipse.ui.views.properties.tabbed.ITabbedPropertyConstants;
import org.eclipse.ui.views.properties.tabbed.TabbedPropertySheetPage;
import org.eclipse.ui.views.properties.tabbed.TabbedPropertySheetWidgetFactory;

/**
 * This is a base class for all property sections in Xdf diagram editor. It
 * configure some member variables and set the current PictogramElement and
 * business object for all subclasses.
 * 
 * @author Antoine Lorence
 * 
 */
abstract public class AbstractDiagramSection extends GFPropertySection implements ITabbedPropertyConstants {

	protected TabbedPropertySheetWidgetFactory widgetFactory;

	private EObject businessObject;
	private Network currentNetwork;
	private PictogramElement pictogramElement;
	private XdfDiagramFeatureProvider featureProvider;

	protected Composite formBody;

	protected final PartialCalParser calParser;

	protected final Color disabledFieldBGColor;
	protected final Color errorColor;

	public AbstractDiagramSection() {
		calParser = new PartialCalParser();
		disabledFieldBGColor = new Color(Display.getCurrent(), new RGB(230, 230, 230));
		errorColor = new Color(Display.getCurrent(), new RGB(242, 152, 152));
	}

	@Override
	public void createControls(Composite parent, TabbedPropertySheetPage aTabbedPropertySheetPage) {
		super.createControls(parent, aTabbedPropertySheetPage);

		widgetFactory = getWidgetFactory();

		final Form form = widgetFactory.createForm(parent);
		form.setText(getFormText());
		widgetFactory.decorateFormHeading(form);
		formBody = form.getBody();
	}

	@Override
	public void setInput(IWorkbenchPart part, ISelection selection) {
		super.setInput(part, selection);

		pictogramElement = getSelectedPictogramElement();
		businessObject = Graphiti.getLinkService().getBusinessObjectForLinkedPictogramElement(pictogramElement);
		currentNetwork = (Network) Graphiti.getLinkService().getBusinessObjectForLinkedPictogramElement(getDiagram());
		featureProvider = (XdfDiagramFeatureProvider) getDiagramTypeProvider()
				.getFeatureProvider();
	}

	//=============
	// Getters
	//=============
	protected EObject getSelectedBusinessObject() {
		return businessObject;
	}
	protected Network getCurrentNetwork() {
		return currentNetwork;
	}

	protected XdfDiagramFeatureProvider getFeatureProvider() {
		return featureProvider;
	}
	protected <T extends IPattern> T getPattern(final PictogramElement pe,
			final Class<T> patternType) {
		final IPattern pattern = getFeatureProvider()
				.getPatternForPictogramElement(pe);
		if (patternType.isInstance(pattern)) {
			return patternType.cast(pattern);
		}
		return null;
	}

	@Override
	public void refresh() {
		readValuesFromModels();
	}

	/**
	 * Executes {@link #writeValuesToModel()} inside a Command suitable for
	 * transactional edition of domain models
	 */
	final protected void writeValuesInTransaction(final Widget widget) {

		// Execute the method in a write transaction, because it will modify the
		// models
		final TransactionalEditingDomain editingDomain = getDiagramContainer().getDiagramBehavior().getEditingDomain();
		editingDomain.getCommandStack().execute(new RecordingCommand(editingDomain) {
			@Override
			protected void doExecute() {
				writeValuesToModel(widget);
			}
		});
	}

	/**
	 * Read values from EMF models and write it to the corresponding widget.
	 */
	protected abstract void readValuesFromModels();

	/**
	 * Read value from the given widget and write it to the corresponding EMF
	 * model.
	 * 
	 * @param widget
	 */
	protected abstract void writeValuesToModel(final Widget widget);

	/**
	 * Check if the value in the given widget is valid. If not, returns a
	 * message explaining why. If it is valid, this method must return null
	 * 
	 * @param widget
	 * @return null if given widget value is valid, an error message instead
	 */
	protected String checkValueValid(final Widget widget) {
		return null;
	}

	protected abstract String getFormText();
}
